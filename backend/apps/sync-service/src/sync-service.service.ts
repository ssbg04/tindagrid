import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { DatabaseService } from '@lib/database';
import { SyncMutationDto } from './dto/sync.dto.js';
import { randomUUID, randomInt } from 'node:crypto';

@Injectable()
export class SyncServiceService {
  private readonly logger = new Logger(SyncServiceService.name);

  constructor(private readonly db: DatabaseService) {}

  /**
   * Helper to resolve and verify store ownership for the authenticated merchant
   */
  private async resolveStore(merchantId: string, requestedStoreId?: string) {
    if (requestedStoreId) {
      const store = await this.db.store.findFirst({
        where: { id: requestedStoreId, merchantId },
      });
      if (!store) {
        throw new ForbiddenException(
          'Walang access sa tindahang ito o hindi umiiral.',
        );
      }
      return store;
    }

    const defaultStore = await this.db.store.findFirst({
      where: { merchantId },
      orderBy: { createdAt: 'asc' },
    });

    if (!defaultStore) {
      throw new NotFoundException(
        'Walang nahanap na tindahan para sa merchant na ito.',
      );
    }

    return defaultStore;
  }

  /**
   * Process incoming client mutations (Delta Push) with conflict resolution
   * - Products: Last-Write-Wins based on updatedAt
   * - Sales: Additive Financial Ledger with clientSaleId idempotency
   * - Debts: Idempotent with Last-Write-Wins balance updates
   * - GCash: Additive Ledger with referenceNumber/idempotency
   */
  async pushMutations(
    merchantId: string,
    requestedStoreId: string | undefined,
    mutations: SyncMutationDto[],
  ) {
    const store = await this.resolveStore(merchantId, requestedStoreId);
    const storeId = store.id;

    const syncedIds: string[] = [];
    const conflicts: any[] = [];

    for (const mutation of mutations) {
      try {
        const { entityTable, operation, payload, clientTimestamp, id } = mutation;
        const recordTime = clientTimestamp
          ? new Date(clientTimestamp)
          : new Date();

        switch (entityTable.toLowerCase()) {
          case 'products': {
            const productId = payload.id || mutation.entityId;
            const existing = await this.db.product.findUnique({
              where: { id: productId },
            });

            if (existing) {
              const incomingTime = payload.updatedAt
                ? new Date(payload.updatedAt)
                : recordTime;

              // Last-Write-Wins: only update if client mutation is newer or equal
              if (incomingTime >= existing.updatedAt) {
                await this.db.product.update({
                  where: { id: productId },
                  data: {
                    barcode: payload.barcode ?? existing.barcode,
                    name: payload.name ?? existing.name,
                    category: payload.category ?? existing.category,
                    costPrice:
                      payload.costPrice !== undefined
                        ? Number(payload.costPrice)
                        : existing.costPrice,
                    sellingPrice:
                      payload.sellingPrice !== undefined
                        ? Number(payload.sellingPrice)
                        : existing.sellingPrice,
                    currentStock:
                      payload.currentStock !== undefined
                        ? Math.round(Number(payload.currentStock))
                        : existing.currentStock,
                    unit: payload.unit ?? existing.unit,
                    isTingi:
                      payload.isTingi !== undefined
                        ? Boolean(payload.isTingi)
                        : existing.isTingi,
                    imageUrl: payload.imageUrl ?? existing.imageUrl,
                    isDeleted:
                      payload.isDeleted !== undefined
                        ? Boolean(payload.isDeleted)
                        : existing.isDeleted,
                    updatedAt: incomingTime,
                  },
                });
                syncedIds.push(id);
              } else {
                // Cloud version is newer: report conflict with server product state
                conflicts.push({
                  id,
                  entityTable: 'products',
                  entityId: productId,
                  resolution: 'SERVER_WINS',
                  serverData: existing,
                });
                // Still mark client mutation as acknowledged so queue does not get stuck
                syncedIds.push(id);
              }
            } else {
              // Product does not exist in cloud: insert
              await this.db.product.create({
                data: {
                  id: productId,
                  storeId,
                  barcode: payload.barcode || null,
                  name: payload.name || 'Unnamed Product',
                  category: payload.category || 'General',
                  costPrice: Number(payload.costPrice || 0),
                  sellingPrice: Number(payload.sellingPrice || 0),
                  currentStock: Math.round(Number(payload.currentStock || 0)),
                  unit: payload.unit || 'pcs',
                  isTingi: Boolean(payload.isTingi || false),
                  imageUrl: payload.imageUrl || null,
                  isDeleted: Boolean(payload.isDeleted || false),
                  createdAt: payload.createdAt ? new Date(payload.createdAt) : recordTime,
                  updatedAt: payload.updatedAt ? new Date(payload.updatedAt) : recordTime,
                },
              });
              syncedIds.push(id);
            }
            break;
          }

          case 'sales': {
            const saleId = payload.id || mutation.entityId;
            // Additive Financial Ledger: Idempotency by clientSaleId
            const existing = await this.db.sale.findFirst({
              where: {
                OR: [{ id: saleId }, { clientSaleId: saleId }],
              },
            });

            if (!existing) {
              await this.db.sale.create({
                data: {
                  id: saleId,
                  storeId,
                  clientSaleId: saleId,
                  totalAmount: Number(payload.totalAmount || 0),
                  estimatedTubo: Number(payload.totalProfit || payload.estimatedTubo || 0),
                  paymentMethod: (payload.paymentMethod || 'CASH').toUpperCase(),
                  items: payload.items || null,
                  createdAt: payload.timestamp
                    ? new Date(payload.timestamp)
                    : recordTime,
                },
              });
            }
            syncedIds.push(id);
            break;
          }

          case 'debts': {
            const debtId = payload.id || mutation.entityId;
            const existing = await this.db.debt.findFirst({
              where: {
                OR: [{ id: debtId }, { clientDebtId: debtId }],
              },
            });

            const debtTime = payload.updatedAt
              ? new Date(payload.updatedAt)
              : recordTime;

            if (existing) {
              if (debtTime >= existing.updatedAt) {
                await this.db.debt.update({
                  where: { id: existing.id },
                  data: {
                    customerName: payload.customerName ?? existing.customerName,
                    customerPhone: payload.customerPhone ?? existing.customerPhone,
                    totalAmount:
                      payload.totalAmount !== undefined
                        ? Number(payload.totalAmount)
                        : existing.totalAmount,
                    remainingBalance:
                      payload.remainingBalance !== undefined
                        ? Number(payload.remainingBalance)
                        : existing.remainingBalance,
                    status: (payload.status || existing.status).toUpperCase(),
                    dueDate: payload.dueDate ? new Date(payload.dueDate) : existing.dueDate,
                    notes: payload.notes ?? existing.notes,
                    updatedAt: debtTime,
                  },
                });
              }
            } else {
              await this.db.debt.create({
                data: {
                  id: debtId,
                  storeId,
                  clientDebtId: debtId,
                  customerName: payload.customerName || 'Customer',
                  customerPhone: payload.customerPhone || null,
                  totalAmount: Number(payload.totalAmount || 0),
                  remainingBalance: Number(
                    payload.remainingBalance !== undefined
                      ? payload.remainingBalance
                      : payload.totalAmount || 0,
                  ),
                  status: (payload.status || 'UNPAID').toUpperCase(),
                  dueDate: payload.dueDate ? new Date(payload.dueDate) : null,
                  notes: payload.notes || null,
                  createdAt: payload.borrowedDate
                    ? new Date(payload.borrowedDate)
                    : recordTime,
                  updatedAt: debtTime,
                },
              });
            }
            syncedIds.push(id);
            break;
          }

          case 'gcash_ledger': {
            const gcashId = payload.id || mutation.entityId;
            const existing = await this.db.gcashLedger.findFirst({
              where: {
                OR: [
                  { id: gcashId },
                  ...(payload.referenceNumber
                    ? [{ referenceNumber: payload.referenceNumber, storeId }]
                    : []),
                ],
              },
            });

            if (!existing) {
              await this.db.gcashLedger.create({
                data: {
                  id: gcashId,
                  storeId,
                  type: (payload.transactionType || 'CASH_IN').toUpperCase(),
                  amount: Number(payload.amount || 0),
                  feeCharged: Number(payload.feeCharged || 0),
                  referenceNumber: payload.referenceNumber || null,
                  createdAt: payload.timestamp
                    ? new Date(payload.timestamp)
                    : recordTime,
                },
              });
            }
            syncedIds.push(id);
            break;
          }

          default: {
            // For other auxiliary tables (e.g. inventory_logs, payables), acknowledge
            syncedIds.push(id);
            break;
          }
        }
      } catch (err: any) {
        this.logger.error(
          `Error syncing mutation ${mutation.id} on table ${mutation.entityTable}: ${err.message}`,
        );
      }
    }

    return {
      success: true,
      syncedCount: syncedIds.length,
      syncedIds,
      conflicts,
      serverTimestamp: new Date().toISOString(),
    };
  }

  /**
   * Pull delta changes from Neon cloud since lastSyncTimestamp
   * Enables seamless multi-device sync between owner's phone and web POS
   */
  async pullDeltas(
    merchantId: string,
    requestedStoreId: string | undefined,
    since?: string,
  ) {
    const store = await this.resolveStore(merchantId, requestedStoreId);
    const storeId = store.id;

    const filterDate = since ? new Date(since) : new Date(0);

    const [products, sales, debts, gcash] = await Promise.all([
      this.db.product.findMany({
        where: {
          storeId,
          updatedAt: { gt: filterDate },
        },
        orderBy: { updatedAt: 'asc' },
      }),
      this.db.sale.findMany({
        where: {
          storeId,
          createdAt: { gt: filterDate },
        },
        orderBy: { createdAt: 'asc' },
      }),
      this.db.debt.findMany({
        where: {
          storeId,
          updatedAt: { gt: filterDate },
        },
        orderBy: { updatedAt: 'asc' },
      }),
      this.db.gcashLedger.findMany({
        where: {
          storeId,
          createdAt: { gt: filterDate },
        },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    return {
      serverTimestamp: new Date().toISOString(),
      store: {
        id: store.id,
        name: store.name,
        slug: store.slug,
      },
      products,
      sales,
      debts,
      gcash,
    };
  }

  /**
   * Cloud Disaster Recovery: Rehydrate full store catalog & ledgers on new device login
   */
  async restoreFullStore(
    merchantId: string,
    requestedStoreId?: string,
  ) {
    const store = await this.resolveStore(merchantId, requestedStoreId);
    const storeId = store.id;

    // Pull full catalog (excluding deleted items)
    const products = await this.db.product.findMany({
      where: { storeId, isDeleted: false },
      orderBy: { name: 'asc' },
    });

    // Pull active/pending customer debts
    const debts = await this.db.debt.findMany({
      where: { storeId },
      orderBy: { createdAt: 'desc' },
    });

    // Pull last 90 days sales
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const sales = await this.db.sale.findMany({
      where: {
        storeId,
        createdAt: { gte: ninetyDaysAgo },
      },
      orderBy: { createdAt: 'desc' },
      take: 500,
    });

    // Pull last 90 days GCash records
    const gcash = await this.db.gcashLedger.findMany({
      where: {
        storeId,
        createdAt: { gte: ninetyDaysAgo },
      },
      orderBy: { createdAt: 'desc' },
      take: 300,
    });

    return {
      success: true,
      serverTimestamp: new Date().toISOString(),
      store: {
        id: store.id,
        name: store.name,
        slug: store.slug,
        address: store.address,
        isPublic: store.isPublic,
      },
      counts: {
        products: products.length,
        debts: debts.length,
        sales: sales.length,
        gcash: gcash.length,
      },
      products,
      debts,
      sales,
      gcash,
    };
  }

  // --- Companion Scanner (Mobile to Web POS Relay) ---
  private readonly companionSessions = new Map<
    string,
    {
      sessionId: string;
      pairingCode: string;
      merchantId?: string;
      storeId?: string;
      createdAt: Date;
      expiresAt: Date;
      scans: Array<{ id: string; barcode: string; scannedAt: string }>;
    }
  >();

  /**
   * Create a new temporary companion scanner session for pairing Web POS with Phone
   */
  createCompanionSession(merchantId?: string, storeId?: string) {
    // Clean up expired sessions (> 30 mins)
    const now = new Date();
    for (const [key, session] of this.companionSessions.entries()) {
      if (session.expiresAt < now) {
        this.companionSessions.delete(key);
      }
    }

    const sessionId = randomUUID();
    const pairingCode = `SCAN-${randomInt(1000, 9999)}`;
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 mins TTL

    const sessionData = {
      sessionId,
      pairingCode,
      merchantId,
      storeId,
      createdAt: now,
      expiresAt,
      scans: [],
    };

    this.companionSessions.set(sessionId, sessionData);
    this.companionSessions.set(pairingCode, sessionData);

    return {
      success: true,
      sessionId,
      pairingCode,
      expiresAt: expiresAt.toISOString(),
      pairUrl: `tindagrid://pair-scanner?sessionId=${sessionId}&code=${pairingCode}`,
    };
  }

  /**
   * Phone pushes scanned barcode into companion session
   */
  pushCompanionScan(sessionIdOrCode: string, barcode: string) {
    const session = this.companionSessions.get(sessionIdOrCode);
    if (!session || session.expiresAt < new Date()) {
      throw new NotFoundException('Companion scanner session expired or invalid.');
    }

    const scanEntry = {
      id: randomUUID(),
      barcode: barcode.trim(),
      scannedAt: new Date().toISOString(),
    };

    session.scans.push(scanEntry);

    // Keep memory lean (last 50 scans per session)
    if (session.scans.length > 50) {
      session.scans.shift();
    }

    this.logger.log(`Companion scan pushed: [${session.pairingCode}] ${barcode}`);

    return {
      success: true,
      scanId: scanEntry.id,
      barcode: scanEntry.barcode,
      scannedAt: scanEntry.scannedAt,
    };
  }

  /**
   * Web POS polls for new scans from the paired smartphone
   */
  pollCompanionScans(sessionIdOrCode: string, sinceScanId?: string) {
    const session = this.companionSessions.get(sessionIdOrCode);
    if (!session || session.expiresAt < new Date()) {
      throw new NotFoundException('Companion scanner session expired or not found.');
    }

    let pendingScans = session.scans;
    if (sinceScanId) {
      const index = session.scans.findIndex((s) => s.id === sinceScanId);
      if (index !== -1) {
        pendingScans = session.scans.slice(index + 1);
      }
    }

    return {
      success: true,
      sessionId: session.sessionId,
      pairingCode: session.pairingCode,
      active: true,
      newScans: pendingScans,
      totalScans: session.scans.length,
    };
  }
}

