$(document).on('focus', 'input, textarea', function() {
    $('div[data-role="header"]').css('position', 'absolute');
    $.mobile.silentScroll($('input:focus').offset().top - 100);
});
$(document).on('blur', 'input, textarea', function() {
    $('div[data-role="header"]').css('position', 'fixed');
});
// Prepare the Post status based on what button is pressed
$(document).ready(function() {

	$('#publish_btn').on('click', function() {
		$('#status').val('published');
	});

	$('#draft_btn').on('click', function() {
		$('#status').val('draft');
	});

	$('#trash_btn').on('click', function() {
		$('#status').val('trash');
	});

//	choose file on input  Create Post page
	$("#cover").on("change", function(){
		var chooseFile = $(this).val();

		if(!stringEndsWithValidExtension(chooseFile, ["jpeg", "jpg", "png", "gif", "png"])) {
			$("#cover").val('');
			displayAlertMessage("The system currently supports jpg, jpeg, png or gif uploads. Please try re-uploading a supported format.", 'danger');
		}
	});

//for safari display error on Create Blog/Admin => submit
	$('#new-blog-form button[type=submit]').click(function(e) {
		e.preventDefault();
		var sendModalForm = true;
		$('#new-blog-form [required]').each(function() {
			if ($(this).val() == '') {
				sendModalForm = false;
			}
		});
		if (sendModalForm) {
			$('#new-blog-form').submit();
		} else {
			displayAlertMessage("Please fill in all the required fields", 'danger');
		}
	});

//for safari display error on Create Post/Admin => submit
	$('#new-post-form button[type=submit]').click(function(e) {
		e.preventDefault();
		var sendModalForm = true;
		$('#new-post-form [required]').each(function() {
			if ($(this).val() == '') {
				sendModalForm = false;
			}
		});
		if (sendModalForm) {
			$('#new-post-form').submit();
		} else {
			displayAlertMessage("Please fill in the required fields.", 'danger');
		}
	});
//for safari display error on Create Post/ Admin => trash
	$('#new-post-form button[type=button]').click(function(e) {
		e.preventDefault();
		$('#new-post-form')[0].reset();
		CKEDITOR.instances.post.setData('');
	});


	// delete blog on Blogs Page/Admin
	$("a.remove-blog").on('click', function(e){
		e.preventDefault();
		var url = $(this).attr("href");
		displayAlertModal({
			title:"Delete Blog" ,
			message: "Are you sure you want to delete this blog? All content will be lost." ,
			okButton: "Yes" ,
			cancelButton: "No"
		}, function(){
			window.location.href = url;
		});

	});
	$('#reset-new-blog').click(function(){
		$('#new-blog-form')[0].reset();
		$('#new-blog-form .chosen-select').trigger("chosen:updated");
	});

//	for safari Users Page/Admin =>add email-user =>cancel
	$('#new-user-email button[type=button]').click(function(e) {
		e.preventDefault();
		$("#new-user-email")[0].reset();
		$("#blog_for_users").trigger("chosen:updated");
	});
//	for safari Users Page/Admin =>add email-user =>submit
	$('#new-user-email button[type=submit]').click(function(e) {
		e.preventDefault();
		var sendModalForm = true;
		$('#new-user-email [required]').each(function() {
			if ($(this).val() == '') {
				sendModalForm = false;
			}
		});
		if (sendModalForm) {
			$('#new-user-email').submit();
		} else {
			displayAlertMessage("Please fill in the required fields.", 'danger');
		}
	});
//	for safari Users Page/Admin =>add email-user =>remove fields, when cancel
	$('#reset-user-email').click(function(){
		$('#new-user-email')[0].reset();
	});
});

// Autocomplete the Tag/Category slug
$(document).ready(function() {
	$("input[name='name']").on('keyup', function(){
		var slug = $(this).val();

		// Replace all non-alphanumeric characters with a hypen
		slug = slug.replace(/([~!@#$%^&*()_+=`{}\[\]\|\\:;'<>,.\/? ])+/g, '-').replace(/^(-)+|(-)+$/g,'').toLowerCase();
		$("input[name='slug']").val(slug);
	});

	$('input[name="title"]').on('keyup', function(){
		var slug = $(this).val();

		// Replace all non-alphanumeric characters with a hypen
		slug = slug.replace(/([~!@#$%^&*()_+=`{}\[\]\|\\:;'<>,.\/? ])+/g, '-').replace(/^(-)+|(-)+$/g,'').toLowerCase();
		$("input[name='slug']").val(slug);
	});
});

// Auto switch the bootstrap switcer on the Settings page.

$(document).ready(function(){
	var state = $('#social_media_state').val();
	state = parseInt(state);

	$('.make-switch').bootstrapSwitch('setState' , state);
});

// Activate the tag input
$(document).ready(function() {
	$.getJSON('/api/tags.json', function(tags_list) {
		$("#tags").select2({tags: tags_list});
	});

});


$(document).ready(function() {

	$.getJSON('/api/categories.json', function(categories_list) {
		$("#categories").select2({tags: categories_list});
	});

});

function getBlogValue() {
	if (window.location.href.split("/")[4] == "users") {
		var e = document.getElementById("users_blogs_list");
	} else if (window.location.href.split("/")[4] == "comments") {
		var e = document.getElementById("comments_blogs_list");
	}
	var blogOption = e.options[e.selectedIndex].value;
	return blogOption;
}

function getRoleValue() {
	var e = document.getElementById("users_role_list");
	var roleOption = e.options[e.selectedIndex].value;
	return roleOption;
}

function getStatusValue() {
	if (window.location.href.split("/")[4] == "users") {
		var e = document.getElementById("users_status_list");
	} else if (window.location.href.split("/")[4] == "comments") {
		var e = document.getElementById("comments_status_list");
	}
	var statusOptions = e.options[e.selectedIndex].value;
	return statusOptions;
}

function createURL() {
	var pageURL = window.location.href.split("/");
	var userRole = pageURL[3];
	if (pageURL[4] == "users") {
		window.location.href = "/" + userRole + "/users/blog/" + getBlogValue() + "/role/" + getRoleValue() + "/status/" + getStatusValue() + "/page/1";
	} else if (pageURL[4] == "comments") {
		window.location.href = "/" + userRole + "/comments/blog/" + getBlogValue() + "/" + getStatusValue() + "/page/1";
	}
}

function getFilterOptions() {
	if (window.location.href.split("/")[4] == "users") {
		sessionStorage.filterOptions = getBlogValue() + "***" + getRoleValue() + "***" + getStatusValue();
	} else if (window.location.href.split("/")[4] == "comments") {
		sessionStorage.filterOptions = getBlogValue() + "***" + getStatusValue();
	}
}

$(document).ready(function () {
	if (sessionStorage.filterOptions) {
		var filter = sessionStorage.filterOptions.split("***");
		function setSelectedOption(s, valsearch) {
			// Search through dropdown for the option you need
			for (i = 0; i < s.options.length; i++) {
				if (s.options[i].value == valsearch) {
					// Found the option you need 
					// And add property selected
					s.options[i].selected = true;
					break;
				}
			}
			return;
		}

		if (window.location.href.split("/")[4] == "users") {
			setSelectedOption(document.getElementById("users_blogs_list"), filter[0]);
			setSelectedOption(document.getElementById("users_role_list"), filter[1]);
			setSelectedOption(document.getElementById("users_status_list"), filter[2]);
			
			$("#users_blogs_dropdown a.chosen-single span").html(filter[0]);
			if (filter[1] == 1) {
				$("#users_role_dropdown a.chosen-single span").html("Admin");
			} else if (filter[1] == 0) {
				$("#users_role_dropdown a.chosen-single span").html("Author");
			}
			$("#users_status_dropdown a.chosen-single span").html(filter[2]);
			
		} else if (window.location.href.split("/")[4] == "comments") {
			setSelectedOption(document.getElementById("comments_blogs_list"), filter[0]);
			setSelectedOption(document.getElementById("comments_status_list"), filter[1]);
			
			$("#comments_blogs_dropdown a.chosen-single span").html(filter[0]);
			$("#comments_status_dropdown a.chosen-single span").html(filter[1]);
		}
	}
	
	$(".sidey").click(function () {
		sessionStorage.clear();
	});
});
// END - Admin dashboard - Users section filter and persistence
// END - Admin dashboard - Comments section filter and persistence


$(document).ready(function(){
 	if($(".err-500") && $(".err-500").length > 0){
 		$(".sidey").remove();
 		$(".sidebar-dropdown").hide();
 	}
 });


//----------------------------
// Validation file input for img only
function stringEndsWithValidExtension(stringToCheck, acceptableExtensionsArray, required) {
	if (required == false && stringToCheck.length == 0) { return true; }
	for (var i = 0; i < acceptableExtensionsArray.length; i++) {
		if (stringToCheck.toLowerCase().endsWith(acceptableExtensionsArray[i].toLowerCase())) { return true; }
	}
	return false;
}

String.prototype.startsWith = function (str) { return (this.match("^" + str) == str) }
String.prototype.endsWith = function (str) { return (this.match(str + "$") == str) }



//Croppie avatars for the creation of the blog avatars
$(document).ready(function() {
// Image upload preview modal cancel button
	$(".modal-footer .cancel-img").on('click', function(){
		var src = $( ".blog-pic #blog_img_preview").attr('src');
		$('#modal_blog_img_preview').attr('src', src);

		if (!$('#modal_blog_img_preview').hasClass('defaultAvatar')) {
			$('#modal_blog_img_preview').addClass('hidden');
			$('#croppie_pic').croppie('bind', {
				url: src
			}, function() {
				$('#croppie_pic .cr-image').css({
					'transform-origin': '20px 20px 0',
					'-webkit-transform-origin': '20px 20px 0',
					'transform': 'translate3d(20px, 20px, 0)',
					'width': '140px',
					'height': '140px'
				});
				$('#croppie_pic .cr-slider').attr('min', 1).attr('max', 2).val(1);
			});

			$('#croppie_pic').removeClass('hidden');
		} else {
			$('#croppie_pic').addClass('hidden');
			$('#modal_blog_img_preview').removeClass('hidden');
			$('#modal_blog_img_preview.defaultAvatar').show();
		}
		$('#upload_blog_img').get(0).reset();
	});


	$('#croppie_pic').croppie({
		url: $('#modal_blog_img_preview').attr('src'),
		viewport: {
			width: 140,
			height: 140,
			type: 'circle'
		},
		boundary: {
			width: 180,
			height: 180
		}
	});

	$('#changeImgBlog').on('show.bs.modal', function() {
		$('#croppie_pic .cr-image').css({
			'transform-origin': '20px 20px 0',
			'transform': 'translate3d(20px, 20px, 0)',
			'width': 140,
			'height': 140
		});
		$('#croppie_pic .cr-slider').attr('min', 1).attr('max', 2);
	});


	//undo the blog avatars when click outside the modal
	$('#changeImgBlog').on('hidden.bs.modal', function(e) {
		$(".modal-footer .cancel-img").trigger('click');
	});


	if (!$('#modal_blog_img_preview').hasClass('defaultAvatar')){
		$('#modal_blog_img_preview').addClass('hidden');
	} else {
		$('#croppie_pic').addClass('hidden');
	}

	// Image upload preview
	function readURL(input) {
		if (input.files && input.files[0]) {
			var reader = new FileReader();
			reader.onload = function (e) {
				$('#modal_blog_img_preview').attr('src', e.target.result).addClass('hidden');
				var imageStyle = $('#croppie_pic .cr-image').get(0).style;
				imageStyle.removeProperty('transform-origin');
				imageStyle.removeProperty('transform');
				imageStyle.removeProperty('width');
				imageStyle.removeProperty('height');

				$('#croppie_pic').croppie('bind', {
					url: e.target.result
				}, function() {
					var minZoom = +$('#croppie_pic .cr-image')[0].style['transform']
						.split(")")
						.find(function(item) {
							return item.indexOf('scale') >=0
						}).replace("scale(", '');

					minZoom = (minZoom < 1) ? minZoom : 1;

					$('#croppie_pic .cr-slider').attr('min', minZoom).attr('max', 2);
				}).removeClass('hidden');
			}
			reader.readAsDataURL(input.files[0]);
		}
	}

	function getOrientation(file, callback) {
		var reader = new FileReader();
		reader.onload = function(e) {

			var view = new DataView(e.target.result);
			if (view.getUint16(0, false) != 0xFFD8) return callback(-2);
			var length = view.byteLength, offset = 2;

			while (offset < length) {
				var marker = view.getUint16(offset, false);
				offset += 2;
				if (marker == 0xFFE1) {
					if (view.getUint32(offset += 2, false) != 0x45786966) return callback(-1);
					var little = view.getUint16(offset += 6, false) == 0x4949;
					offset += view.getUint32(offset + 4, little);
					var tags = view.getUint16(offset, little);
					offset += 2;
					for (var i = 0; i < tags; i++)
						if (view.getUint16(offset + (i * 12), little) == 0x0112)
							return callback(view.getUint16(offset + (i * 12) + 8, little));
				}
				else if ((marker & 0xFF00) != 0xFF00) break;
				else offset += view.getUint16(offset, false);
			}

			return callback(-1);
		};
		reader.readAsArrayBuffer(file.slice(0, 64 * 1024));
		//	console.log(orientation);
	}

	var input = document.getElementById('file-upload-blog');
	if (input) {
		input.onchange = function(e) {
			getOrientation(input.files[0], function(orientation) {
				if (orientation === 6) {
					$(".croppie-container .cr-boundary").rotate({animateTo:90});
				}
			});
		}
	}

	$("#file-upload-blog").change(function () {
		readURL(this);
		//getOrientation(this);
	});


	//delete image
	$(".modal-footer .delete-img").on('click', function(){
		var themeinitial = $('#cmn-toggle-4').is(':checked');
		$( "#file-upload-blog" ).val("");
		if (themeinitial === false){
			$('#modal_blog_img_preview').attr('src', '/blog/img/blog_dark_large.png');
		} else if (themeinitial === true) {
			$('#modal_blog_img_preview').attr('src', '/blog/img/blog_light_large.png');
		}

		$('[name=action_form]').val('delete');

		$('#modal_blog_img_preview').removeClass('hidden');
		$('#croppie_pic').addClass('hidden');
	});

	//submitting upload picture form
	$("#changeImgBlog .save-img").click(function() {
		if (!stringEndsWithValidExtension($("[id*='file-upload-blog']").val(), [".png", ".jpeg", ".jpg", ".bmp", ".gif"], false)) {
			$('.error_file').fadeIn().delay(3000).fadeOut(2000);
			return false;
		}

		if (!$('#croppie_pic').hasClass('hidden')) {
			//croppie avatars
			var cropData = $('#croppie_pic').croppie('get');
			var topLeftX = cropData.points[0];
			var topLeftY = cropData.points[1];
			var bottomRightX = cropData.points[2];
			var bottomRightY = cropData.points[3];

			var widthCrop = bottomRightX - topLeftX;
			var heightCrop = bottomRightY - topLeftY;
			var top = topLeftY;
			var left = topLeftX;

			$('#upload_blog_img [name=top]').val(top);
			$('#upload_blog_img [name=left]').val(left);
			$('#upload_blog_img [name=width]').val(widthCrop);
			$('#upload_blog_img [name=height]').val(heightCrop);
			$('#upload_blog_img [name=zoom]').val(cropData.zoom);

			if (widthCrop !== '0' || heightCrop !== '0' || top !== '0' || left !== '0') {
				$('[name=action_form]').val('crop');
			}
		}

		$("#upload_blog_img").submit();
	});



	$('#blog-select').on("change", function(e){
		var blogName = e.target.value,
			blogUsername = $("#sessionUsername").text(),
			blogSlug = $(this).find("option[value='"+ blogName + "']").attr("data-slug"),
			blogSrc = "/blog_avatar/" + blogName;

		$('#upload_blog_img').attr('action', '/blog-image/large/blog/' + blogName);

		if(imageExists(blogSrc)){
			$("#blog_img_preview").attr('src', blogSrc);
			$("#blog_img_preview").removeClass("defaultAvatar");
			$("#modal_blog_img_preview").attr('src', blogSrc);
			$("#modal_blog_img_preview").removeClass("defaultAvatar");
		} else{
			$("#blog_img_preview").attr('src', "/blog-avatar/large/");
			$("#blog_img_preview").addClass("defaultAvatar");
			$("#modal_blog_img_preview").attr('src', "/blog-avatar/large/");
			$("#modal_blog_img_preview").addClass("defaultAvatar");
		}

		function imageExists(image_url){

			var http = new XMLHttpRequest();

			http.open('HEAD', image_url, false);
			http.send();

			return http.status != 404;

		}
	});
//	Keep selected value of drop down list after page refresh

});

