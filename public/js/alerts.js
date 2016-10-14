/**
 * Created by mihaelamarinca on 10/14/2016.
 */

//function for Display Alerts : Info, Success, Warning, Danger
function displayAlertMessage(message, type) {
    if (!type){
        type = 'warning';
    }
    $('.alert-message p').text(message);
    $('.alert-message').show();
    $(".alert-message .alert").removeClass("alert-success alert-warning alert-danger alert-info").addClass("alert-"+type);

    var offsetTop = $(".alert-message").offset().top;
    $("html, body").animate({
        scrollTop: offsetTop - 90
    }, 200);


    $(".alert-message .close").one("click", function(){
        $(this).parents(".alert-message").hide();
    })
}

/**
 * Function that will display an alert into a modal window
 * @param {object} opts Configuration object for the alert window
 * @param opts.title The title displayed in the modal header
 * @param opts.message The alert message
 * @param opts.okButton The text of the ok button. Defaults to 'OK'. Set to false to hide the button.
 * @param opts.cancelButton The text of the cancel button. Defaults to 'CANCEL'. Set to false to hide the button.
 * @param {function} callback The function to be called when clicking on the 'ok' button
 */
function displayAlertModal(opts, callback) {
    opts = opts || {};
    var msgContainer = $('#alerts-modal'),
        okBtnText = (opts.okButton === false) ? false : opts.okButton || 'OK',
        cancelBtnText = (opts.cancelButton === false) ? false : opts.cancelButton || 'CANCEL',
        okBtn = msgContainer.find('.ok-btn'),
        cancelBtn = msgContainer.find('.cancel-btn');

    msgContainer.find('.modal-title').text(opts.title);

    if (okBtnText === false) {
        okBtn.hide();
    } else {
        okBtn.text(okBtnText);
    }

    if (cancelBtnText === false) {
        cancelBtn.hide();
    } else {
        cancelBtn.text(cancelBtnText);
    }

    msgContainer.find('.modal-body').html(opts.message);


    msgContainer.find('.ok-btn').one('click', function() {
        msgContainer.modal('hide');
        if (typeof callback === 'function') {
            callback();
        }
    });


    msgContainer.modal();
    msgContainer.on('hidden.bs.modal', function () {
        okBtn.show().unbind('click');
        cancelBtn.show();
    });
}