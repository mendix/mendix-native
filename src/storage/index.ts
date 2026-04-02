import AsyncStorage from '@react-native-async-storage/async-storage';
import NativeMxStorage from './NativeMxStorage';

/**
 * Storage API for managing app data (AsyncStorage, SQLite databases).
 *
 * Provides a unified, type-safe interface for clearing and managing storage
 * across the Mendix Native application.
 *
 * **Modern Architecture:** This API calls TurboModules directly without using
 * the legacy RCTBridge, providing better performance and compatibility with
 * React Native's New Architecture.
 *
 * @example
 * ```typescript
 * import { Storage } from 'mendix-native';
 *
 * // Clear all storage
 * await Storage.clearAll();
 *
 * // Clear specific storage
 * await Storage.clearAsyncStorage();
 * await Storage.clearDatabases();
 * ```
 */
export const Storage = {
  /**
   * Clears all AsyncStorage data.
   *
   * This removes all key-value pairs stored via React Native's AsyncStorage.
   * Calls the AsyncStorage TurboModule directly for optimal performance.
   *
   * @throws {Error} If AsyncStorage module is not available or clear fails
   * @example
   * ```typescript
   * await Storage.clearAsyncStorage();
   * ```
   */
  async clearAsyncStorage(): Promise<void> {
    // Call AsyncStorage TurboModule directly (no bridge, no wrapper)
    await AsyncStorage.clear();
  },

  /**
   * Deletes all SQLite databases.
   *
   * This removes all databases created by the op-sqlite module.
   * Use with caution as this is irreversible.
   *
   * @throws {Error} If OPSQLite module is not available
   * @example
   * ```typescript
   * await Storage.clearDatabases();
   * ```
   */
  async clearDatabases(): Promise<void> {
    return NativeMxStorage.clearDatabases();
  },

  /**
   * Closes all SQLite database connections.
   *
   * This gracefully closes all open database connections without deleting data.
   * Useful before app termination or data clearing operations.
   *
   * @throws {Error} If OPSQLite module is not available
   * @example
   * ```typescript
   * await Storage.closeDatabaseConnections();
   * ```
   */
  async closeDatabaseConnections(): Promise<void> {
    return NativeMxStorage.closeDatabaseConnections();
  },

  /**
   * Clears all app storage (AsyncStorage + SQLite databases).
   *
   * This is a convenience method that clears both AsyncStorage and databases
   * in a single call. Operations are performed sequentially to ensure proper cleanup.
   *
   * JavaScript orchestrates the clearing process, calling each TurboModule directly
   * for optimal performance.
   *
   * @throws {Error} If any storage module is not available
   * @example
   * ```typescript
   * // Clear everything
   * await Storage.clearAll();
   * ```
   */
  async clearAll(): Promise<void> {
    // JavaScript orchestrates - call each TurboModule directly
    await this.clearAsyncStorage();
    await this.clearDatabases();
  },
};
