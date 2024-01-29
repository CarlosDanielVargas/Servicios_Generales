import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="validate-request"
export default class extends Controller {
  connect() {
  }

  validate(event) {
    const inputs = document.querySelectorAll(".input");
    this.#updateInputs(inputs);

    var emptyInputs = "",
      input,
      displayStatus,
      childInputLabel,
      childInputValue;

    for (var i = 0, j = 1; i < inputs.length; i++) {
      input = inputs[i];
      displayStatus = (window.getComputedStyle(input)).getPropertyValue("display");
      childInputValue = (input.childNodes[3].value).trim();

      if (displayStatus == "block" && childInputValue === "") {
        childInputLabel = input.childNodes[1].innerHTML;
        emptyInputs += `\t  ${j}) ${childInputLabel} \n`; // '--> #) Label': Formato que se mostrara en el alert para los campos en blanco
        input.childNodes[3].classList.add("invalid-input");
        j++;
      }
    }

    if (emptyInputs != "") {
      alert(`Los siguientes campos quedaron vacíos y son necesarios para la creación de la solicitud:\n\n${emptyInputs}`); 
      event.preventDefault();
    }
  }

  #updateInputs(inputs) {
    var inputField = "";
    inputs.forEach((input) => {
      inputField = input.childNodes[3];

      if (inputField.value) {
        inputField.classList.remove("invalid-input");
      }
    });
  }
}
