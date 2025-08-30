import { api, LightningElement } from 'lwc';

export default class FileInfo extends LightningElement {
  @api file;
  @api columnMapping;

  get totalColumns() {
    return this.columnMapping.length;
  }

  get totalMappedColumns() {
    return this.columnMapping.filter(column => column.field).length;
  }
}
