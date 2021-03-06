import {
  ConstrainMode,
  DetailsList,
  DetailsListLayoutMode,
  SelectionMode
} from 'office-ui-fabric-react/lib/DetailsList'
import { MarqueeSelection } from 'office-ui-fabric-react/lib/MarqueeSelection'
import * as strings from 'ProjectExtensionsStrings'
import * as React from 'react'
import { format } from 'office-ui-fabric-react/lib/Utilities'
import { InfoMessage } from '../../InfoMessage'
import {
  DocumentTemplateDialogScreenSelectDefaultProps,
  IDocumentTemplateDialogScreenSelectProps
} from './IDocumentTemplateDialogScreenSelectProps'

export class DocumentTemplateDialogScreenSelect extends React.Component<
  IDocumentTemplateDialogScreenSelectProps,
  {}
> {
  public static defaultProps = DocumentTemplateDialogScreenSelectDefaultProps

  public render(): React.ReactElement<IDocumentTemplateDialogScreenSelectProps> {
    return (
      <>
        <InfoMessage
          text={format(
            strings.DocumentTemplateDialogScreenSelectInfoText,
            this.props.templateLibrary.url,
            this.props.templateLibrary.title
          )}
        />
        <MarqueeSelection selection={this.props.selection}>
          <DetailsList
            items={this.props.templates}
            columns={this.props.columns}
            selection={this.props.selection}
            selectionMode={SelectionMode.multiple}
            layoutMode={DetailsListLayoutMode.justified}
            constrainMode={ConstrainMode.horizontalConstrained}
          />
        </MarqueeSelection>
      </>
    )
  }
}
