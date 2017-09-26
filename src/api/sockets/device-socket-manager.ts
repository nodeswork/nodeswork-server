import { nam }                                        from '@nodeswork/nam/dist/def';
import { NAMSocketRpcClient as O_NAMSocketRpcClient } from '@nodeswork/nam/dist/client';
import { Device }                                     from '../models';

export interface DeviceSocket extends SocketIO.Socket {
  device: Device;
}

export class NAMSocketRpcClient extends O_NAMSocketRpcClient {

  public socket: DeviceSocket;

}

export class DeviceSocketManager {

  private deviceSocketMap: { [name: string]: NAMSocketRpcClient; } = {};
  public size = 0;

  public register(socket: DeviceSocket): NAMSocketRpcClient {
    const idStr = socket.device._id.toString();
    if (this.deviceSocketMap[idStr] == null) {
      this.size++;
    }
    const result = new NAMSocketRpcClient(socket);
    this.deviceSocketMap[idStr] = result;
    return result;
  }

  public unregister(socket: DeviceSocket) {
    const idStr = socket.device._id.toString();
    if (this.deviceSocketMap[idStr] != null) {
      this.size--;
    }
    delete this.deviceSocketMap[idStr];
  }

  public isDeviceOnline(deviceId: string): boolean {
    return deviceId in this.deviceSocketMap;
  }

  public getNAMSocketRpcClient(deviceId: string): NAMSocketRpcClient {
    return this.deviceSocketMap[deviceId];
  }

  public updateDevice(device: Device) {
    const idStr = device._id.toString();
    const rpcClient = this.deviceSocketMap[idStr];
    if (rpcClient != null) {
      rpcClient.socket.device = device;
    }
  }
}

export const deviceSocketManager = new DeviceSocketManager();
