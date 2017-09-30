import * as models          from '../../models';

export async function transformUserApplet(
  userApplet: models.UserApplet,
): Promise<models.UserApplet> {
  const result = userApplet.toJSON() as any;
  const target = await userApplet.populateAppletConfig();
  result.config.appletConfig = target;
  result.config.upToDate = (
    target._id.toString() === result.applet.config._id.toString()
  );
  const stats = await userApplet.stats();
  result.stats = stats;
  return result;
}
