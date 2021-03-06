from flask_user.forms import RegisterForm
from flask_wtf import Form
from wtforms import StringField, SubmitField, ValidationError, BooleanField, SelectField, SelectMultipleField, validators
from wtforms.validators import DataRequired, Email

from docassemble.base.functions import word

def fix_nickname(form, field):
    field.data = form.first_name.data + ' ' + form.last_name.data
    return

class MyRegisterForm(RegisterForm):
    first_name = StringField(word('First name'))
    last_name = StringField(word('Last name'))
    social_id = StringField(word('Social ID'))
    nickname = StringField(word('Nickname'), [fix_nickname])

def length_two(form, field):
    if len(field.data) != 2:
        raise ValidationError(word('Must be a two-letter code'))

class NewPrivilegeForm(Form):
    name = StringField(word('Name of new privilege'), validators=[
        DataRequired(word('Name of new privilege is required'))])
    submit = SubmitField(word('Add'))

class UserProfileForm(Form):
    first_name = StringField(word('First name'), validators=[
        DataRequired(word('First name is required'))])
    last_name = StringField(word('Last name'), validators=[
        DataRequired(word('Last name is required'))])
    country = StringField(word('Country code'), [validators.Length(min=0, max=2)])
    subdivisionfirst = StringField(word('First subdivision'), [validators.Length(min=0, max=3)])
    subdivisionsecond = StringField(word('Second subdivision'))
    subdivisionthird = StringField(word('Third subdivision'))
    organization = StringField(word('Organization'))
    timezone = SelectField(word('Time Zone'))
    submit = SubmitField(word('Save'))

class EditUserProfileForm(UserProfileForm):
    email = StringField(word('E-mail'), validators=[Email(word('Must be a valid e-mail address')), DataRequired(word('E-mail is required'))])
    role_id = SelectMultipleField(word('Privileges'), coerce=int)
    active = BooleanField(word('Active'))

class RequestDeveloperForm(Form):
    reason = StringField(word('Reason for needing developer account (optional)'))
    submit = SubmitField(word('Submit'))
