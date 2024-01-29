import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["select", "hidden", "field", "studentid"];
    static classes = ["hidden"];

    connect() {
        this.addDefaultOption();
        this.hiddenTarget.hidden = true;
        this.studentidTarget.style.display = "none";
    }

    select() {
        let options = this.selectTarget;
        let lastOptionIndex = options.length - 1;
        let lastOptionValue = options.options[lastOptionIndex].value;
        if (options.selectedIndex === lastOptionIndex) {
            if (options.id == "request_requester_type") {
                this.studentidTarget.style.display = "block";
            }
            this.hiddenTarget.hidden = false;
        } else {
            if (options.id == "request_requester_type") {
                this.studentidTarget.style.display = "none";
            }
            this.hiddenTarget.hidden = true;
        }
        if (lastOptionValue.includes('other')) {
            if (options.selectedIndex !== lastOptionIndex) {
                this.fieldTarget.value = options.value;
            } else {
                this.fieldTarget.value = "";
            }
        }
    }

    addDefaultOption() {
        const dropdown = this.selectTarget;
        const option = document.createElement("option");
        option.text = "Seleccione una opción";
        option.value = "";
        option.selected = true;
        option.disabled = true;
        dropdown.insertBefore(option, dropdown.firstChild);
    }
}