import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { Logger, LogLevel, ConsoleListener } from '@pnp/logging';
import { sp } from '@pnp/sp';
import { WebPartContext } from '@microsoft/sp-webpart-base';
import HubSiteService, { IHubSite } from 'sp-hubsite-service';
import SpEntityPortalService, { ISpEntityPortalServiceParams } from 'sp-entityportal-service';

export interface IBaseWebPartProps {
  title: string;
  context: WebPartContext;
  hubSite: IHubSite;
  spEntityPortalService: SpEntityPortalService;
  siteId: string;
  userId: string;
  webTitle: string;
  entity: ISpEntityPortalServiceParams;
}

export default class BaseWebPart<P extends IBaseWebPartProps> extends BaseClientSideWebPart<P> {
  public isInitialized: boolean;
  public hubSite: IHubSite;
  public spEntityPortalService: SpEntityPortalService;

  constructor() {
    super();
    Logger.activeLogLevel = LogLevel.Info;
    Logger.subscribe(new ConsoleListener());
  }

  public async onInit() {
    const { pageContext } = this.context;
    const { hubSiteId } = pageContext.legacyPageContext;
    this.hubSite = await HubSiteService.GetHubSiteById(pageContext.web.absoluteUrl, hubSiteId);
    const params = { webUrl: this.hubSite.url, ...this.properties.entity };
    this.spEntityPortalService = new SpEntityPortalService(params);
    sp.setup({ spfxContext: this.context });
  }

  public render(): void { }

  /**
   * Renders the component if initialized
   * 
   * @param {any} component Component
   * @param {Object} properties Properties
   */
  public _render(component: any, properties: Object = {}) {
    this.context.statusRenderer.clearLoadingIndicator(this.domElement);
    if (this.isInitialized) {
      const element: React.ReactElement<any> = React.createElement(component, {
        ...(this.properties as any),
        context: this.context,
        hubSite: this.hubSite,
        spEntityPortalService: this.spEntityPortalService,
        siteId: this.context.pageContext.site.id.toString(),
        userId: this.context.pageContext.legacyPageContext.userId,
        webTitle: this.context.pageContext.web.title,
        ...properties,
      });
      ReactDom.render(element, this.domElement);
    }
  }

  protected get dataVersion(): Version {
    return Version.parse(this.manifest.version);
  }
}