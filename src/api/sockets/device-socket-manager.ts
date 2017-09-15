import { nam }                                        from '@nodeswork/nam/dist/def';
import { NAMSocketRpcClient as O_NAMSocketRpcClient } from '@nodeswork/nam/dist/client';
import { Device }                                     from '../models';

export interface DeviceSocket extends SocketIO.Socket {
  device: Device;
}

export class NAMSocketRpcClient extends O_NAMSocketRpcClient {

  private psResult: nam.AppletStatus[] = null;

  public async ps(): Promise<nam.AppletStatus[]> {
    const result = await super.ps();
    this.psResult = result;
    return result;
  }

  public psInCache(): nam.AppletStatus[] {
    return this.psResult;
  }
}

export class DeviceSocketManager {

  private deviceSocketMap: { [name: string]: NAMSocketRpcClient; } = {};
  public size = 0;

  public register(socket: DeviceSocket) {
    const idStr = socket.device._id.toString();
    if (this.deviceSocketMap[idStr] == null) {
      this.size++;
    }
    this.deviceSocketMap[idStr] = new NAMSocketRpcClient(socket);
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
}

export const deviceSocketManager = new DeviceSocketManager();
