import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller {
  connect() {
  }

  confirm(event) {
    const message = "¿Está seguro(a) que desea realizar esta acción?";
    if (!window.confirm(message)) {
      event.preventDefault();
    } 
  }
}
