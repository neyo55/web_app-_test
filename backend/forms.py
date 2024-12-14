from flask_wtf import FlaskForm
from wtforms import StringField, EmailField, DateField, TextAreaField, SelectField, TelField, SubmitField
from wtforms.validators import DataRequired, Length, Regexp, Email

class UserForm(FlaskForm):
    name = StringField(
        'Name',
        validators=[
            DataRequired(),
            Length(min=2, max=50),
            Regexp(r'^[A-Za-z\s]+$', message="Name must contain only letters and spaces.")  # Ensures name contains only letters and spaces
        ]
    )
    
    email = EmailField(
        'Email',
        validators=[
            DataRequired(),
            Email(message='Invalid email address.')
        ]
    )
    
    phone = TelField(
        'Phone Number',
        validators=[
            DataRequired(),
            Regexp(r'^0[0-9]{10}$', message="Enter a valid phone number (e.g., 08012345678).")  # Correct format for a phone number starting with 0
        ]
    )
    
    dob = DateField('Date of Birth', format='%Y-%m-%d', validators=[DataRequired()])
    gender = SelectField('Gender', choices=[('male', 'Male'), ('female', 'Female'), ('other', 'Other')], validators=[DataRequired()])
    address = TextAreaField('Address', validators=[Length(max=200)])
    submit = SubmitField('Submit')
