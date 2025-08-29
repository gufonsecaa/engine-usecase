import { LightningElement } from 'lwc';

export default class MapColumns extends LightningElement {

  handleMappingFinished() {
    this.dispatchEvent(new CustomEvent('mappingfinished', {}));
  }
}
