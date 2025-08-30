import { api, LightningElement } from 'lwc';

export default class ImportStats extends LightningElement {
  @api fileInfo;
  @api columnMapping;
}
