import { NAMSocketRpcClient } from '@nodeswork/nam/dist/client';
import { Device }             from '../models';

export interface DeviceSocket extends SocketIO.Socket {
  device: Device;
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
}

export const deviceSocketManager = new DeviceSocketManager();
