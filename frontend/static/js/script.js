// script.js
function showAlert(message) {
    document.getElementById('alertMessage').innerText = message;
    document.getElementById('customAlert').style.display = 'block';
}

function closeAlert() {
    document.getElementById('customAlert').style.display = 'none';
}

function validateForm() {
    const nameInput = document.getElementById('name');
    const phoneInput = document.getElementById('phone');
    const dobInput = document.getElementById('dob');
    
    const namePattern = /^[A-Za-z\s]+$/;
    const phonePattern = /^0[0-9]{10}$/;
    const dob = new Date(dobInput.value);
    const today = new Date();
    
    // Validate Name
    if (!namePattern.test(nameInput.value)) {
        showAlert('Name must contain only letters and spaces.');
        return false; // Prevent form submission
    }

    // Validate Phone Number
    if (!phonePattern.test(phoneInput.value)) {
        showAlert('Enter a valid phone number (e.g., 08012345678).');
        return false; // Prevent form submission
    }

    // Validate Date of Birth
    const ageDiffMs = today - dob;
    const ageDate = new Date(ageDiffMs);
    const age = Math.abs(ageDate.getUTCFullYear() - 1970);

    if (dob > today) {
        showAlert('Please enter a valid date of birth. Future dates are not allowed.');
        return false; // Prevent form submission
    }

    if (age < 10) {
        showAlert('Please enter a valid date of birth. You must be at least 10 years old.');
        return false; // Prevent form submission
    }

    return true; // Allow form submission if all validations pass
}

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('dataForm');
    form.addEventListener('submit', (event) => {
        if (!validateForm()) {
            event.preventDefault(); // Prevent form submission
        }
    });
});
