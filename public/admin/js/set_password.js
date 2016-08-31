/**
 * Created by mihaelamarinca on 8/31/2016.
 */
$(document).ready(function() {
    $("#password1").keyup(check);
    $("#password2").keyup(validate);
});

function check() {
    var password1 = $("#password1").val();
    if(password1.length < 6 ) {
        $("#validate-status1").text("Password is too short");
        $("#validate-status1").css({'color':'red'});
    }
    else {
        $("#validate-status1").text(" ");
    }
}

function validate() {
    var password1 = $("#password1").val();
    var password2 = $("#password2").val();

    if(password1 == password2) {
        $("#validate-status2").text(" ");
    }
    else {
        $("#validate-status2").text("Passwords do not match");
        $("#validate-status2").css({'color':'red'});
    }
}