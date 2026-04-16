import AsyncStorage from '@react-native-async-storage/async-storage';
import { open } from '@op-engineering/op-sqlite';
import { beforeEach, describe, expect, test } from 'react-native-harness';
import { Storage } from 'mendix-native';

const DB_NAME = 'storage-harness.sqlite';
const TABLE_NAME = 'storage_harness_records';

async function seedDatabase(): Promise<void> {
  const db = open({ name: DB_NAME });

  await db.execute(
    `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (id INTEGER PRIMARY KEY NOT NULL, value TEXT NOT NULL)`
  );
  await db.execute(`DELETE FROM ${TABLE_NAME}`);
  await db.execute(`INSERT INTO ${TABLE_NAME} (value) VALUES (?)`, ['fixture']);

  db.close();
}

async function getRowCount(): Promise<number> {
  const db = open({ name: DB_NAME });
  const result = await db.execute(
    `SELECT COUNT(*) AS count FROM ${TABLE_NAME}`
  );
  const rowCount = Number(result.rows?.[0]?.count ?? 0);

  db.close();

  return rowCount;
}

async function tableExists(): Promise<boolean> {
  const db = open({ name: DB_NAME });
  const result = await db.execute(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    [TABLE_NAME]
  );
  const exists = result.rows.length > 0;

  db.close();

  return exists;
}

describe('Storage', () => {
  beforeEach(async () => {
    await AsyncStorage.clear();

    try {
      await Storage.closeDatabaseConnections();
    } catch {
      // Ignore cleanup failures so the real test can surface the error.
    }

    try {
      await Storage.clearDatabases();
    } catch {
      // Ignore cleanup failures so the real test can surface the error.
    }
  });

  describe('clearAsyncStorage', () => {
    test('removes previously persisted AsyncStorage keys', async () => {
      await AsyncStorage.setItem('storage-harness:key-1', 'value-1');
      await AsyncStorage.setItem('storage-harness:key-2', 'value-2');

      await Storage.clearAsyncStorage();

      const values = await AsyncStorage.multiGet([
        'storage-harness:key-1',
        'storage-harness:key-2',
      ]);

      expect(values).toEqual([
        ['storage-harness:key-1', null],
        ['storage-harness:key-2', null],
      ]);
    });
  });

  describe('closeDatabaseConnections', () => {
    test('closes active sqlite connections without deleting persisted data', async () => {
      const db = open({ name: DB_NAME });

      await db.execute(
        `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (id INTEGER PRIMARY KEY NOT NULL, value TEXT NOT NULL)`
      );
      await db.execute(`DELETE FROM ${TABLE_NAME}`);
      await db.execute(`INSERT INTO ${TABLE_NAME} (value) VALUES (?)`, [
        'fixture',
      ]);

      await Storage.closeDatabaseConnections();

      expect(await getRowCount()).toBe(1);
    });
  });

  describe('clearDatabases', () => {
    test('removes sqlite schema created through op-sqlite', async () => {
      await seedDatabase();
      expect(await tableExists()).toBe(true);

      await Storage.clearDatabases();

      expect(await tableExists()).toBe(false);
    });
  });

  describe('clearAll', () => {
    test('clears AsyncStorage and sqlite state in one call', async () => {
      await AsyncStorage.setItem('storage-harness:combined', 'present');
      await seedDatabase();

      await Storage.clearAll();

      expect(await AsyncStorage.getItem('storage-harness:combined')).toBe(null);
      expect(await tableExists()).toBe(false);
    });
  });
});
