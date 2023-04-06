import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="validate-request"
export default class extends Controller {
  connect() {
  }

  validate(event) {
    const inputs = document.querySelectorAll(".input");
    
    var inputField = "";
    inputs.forEach((input) => {
      inputField = input.childNodes[3];

      if (inputField.value) {
        console.log(inputField);
        inputField.classList.remove("invalid-input");
      }
    });

    var values = "", displayStatus = "", input = "", childInputLabel = "", childInputValue = "";

    for (var i = 0, j = 1; i < inputs.length; i++) {
      input = inputs[i];
      displayStatus = (window.getComputedStyle(input)).getPropertyValue("display");
      childInputValue = (input.childNodes[3].value).trim();

      if (displayStatus == "block" && childInputValue === "") {
        childInputLabel = input.childNodes[1].innerHTML;
        values += "\t  " + j + ") " + childInputLabel + "\n";
        j++;
        input.childNodes[3].classList.add("invalid-input");
      }
    }

    if (values != "") {
      alert("Los siguientes campos quedaron vacíos y son necesarios para la creación de la solicitud: \n\n" + values); 
      event.preventDefault();
    }
  }
}
