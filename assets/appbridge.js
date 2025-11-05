/**
 * AppBridgeH5 SDK - 主入口文件
 * 统一的 H5 ↔ 原生 SDK 桥接接口
 */
// 导入所有模块
import CoreModule from './modules/core';
import EventsModule from './modules/events';
import AppModule from './modules/app';
import NavModule from './modules/nav';
import UIModule from './modules/ui';
import StorageModule from './modules/storage';
import PermissionModule from './modules/permission';
import DeviceModule from './modules/device';
import ShareModule from './modules/share';
import NotificationsModule from './modules/notifications';
import AuthModule from './modules/auth';
import DownloadModule from './modules/download';
import AppStoreModule from './modules/appstore';
import DeeplinkModule from './modules/deeplink';
import LiveActivityModule from './modules/liveactivity';
// 导出所有类型
export * from './modules/core';
export * from './modules/events';
export * from './modules/app';
export * from './modules/nav';
export * from './modules/ui';
export * from './modules/storage';
export * from './modules/permission';
export * from './modules/device';
export * from './modules/share';
export * from './modules/notifications';
export * from './modules/auth';
export * from './modules/download';
export * from './modules/appstore';
export * from './modules/deeplink';
export * from './modules/liveactivity';
/**
 * AppBridgeH5 主类
 */
class AppBridgeH5 {
    constructor() {
        this.initialized = false;
        // 初始化所有模块
        this.core = new CoreModule();
        this.events = new EventsModule();
        this.app = new AppModule();
        this.nav = new NavModule();
        this.ui = new UIModule();
        this.storage = new StorageModule();
        this.permission = new PermissionModule();
        this.device = new DeviceModule();
        this.share = new ShareModule();
        this.notifications = new NotificationsModule();
        this.auth = new AuthModule();
        this.download = new DownloadModule();
        this.appstore = new AppStoreModule();
        this.deeplink = new DeeplinkModule();
        this.liveActivity = new LiveActivityModule();
        this.init();
    }
    /**
     * 初始化 SDK
     */
    async init() {
        try {
            // 等待原生初始化完成
            await this.core.ready();
//            // 触发 ready 事件
//            this.events.emit('ready');
            this.initialized = true;
        }
        catch (error) {
            console.error('AppBridgeH5 initialization failed:', error);
//            this.events.emit('error', { message: 'Initialization failed', error });
        }
    }
    /**
     * 检查是否已初始化
     */
    isReady() {
        return this.initialized;
    }
    /**
     * 等待初始化完成
     */
    async waitForReady() {
        if (this.initialized) {
            return true;
        }
        return new Promise((resolve) => {
            const checkReady = () => {
                if (this.initialized) {
                    resolve(true);
                }
                else {
                    setTimeout(checkReady, 100);
                }
            };
            checkReady();
        });
    }
    /**
     * 获取 SDK 版本信息
     */
    getVersion() {
        return '1.2.3';
    }
    /**
     * 检查方法是否可用
     */
    async hasMethod(path) {
        const result = await this.core.has(path);
        return result.code === 0 && result.data;
    }
    /**
     * 获取所有可用方法
     */
    async getCapabilities() {
        const result = await this.core.getCapabilities();
        return result.code === 0 ? result.data : [];
    }
}
// 创建全局实例
const appBridge = new AppBridgeH5();
// 挂载到全局对象
if (typeof window !== 'undefined') {
    window.AppBridge = appBridge;
}
// 导出实例和类
export default appBridge;
export { AppBridgeH5 };
// 兼容性导出
export const AppBridge = appBridge;
//# sourceMappingURL=index.js.map