/* ============================================================
    All of the aplication's custom javascript scripts goes here
   ============================================================

Author: Andrei Cacio
Email: andrei.cacio@evozon.com

*/

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

});

// Autocomplete the Tag/Category slug

$(document).ready(function() {

	$('input[name="name"').on('keyup', function(){
		var slug = $(this).val();

		// Replace all non-alphanumeric characters with a hypen
		slug = slug.replace(/([~!@#$%^&*()_+=`{}\[\]\|\\:;'<>,.\/? ])+/g, '-').replace(/^(-)+|(-)+$/g,'').toLowerCase();

		$('input[name="slug"]').val(slug);
	});

	$('input[name="title"').on('keyup', function(){
		var slug = $(this).val();

		// Replace all non-alphanumeric characters with a hypen
		slug = slug.replace(/([~!@#$%^&*()_+=`{}\[\]\|\\:;'<>,.\/? ])+/g, '-').replace(/^(-)+|(-)+$/g,'').toLowerCase();

		$('input[name="slug"]').val(slug);
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

$('.page-content').css('min-height',$(window).height()-$('.header').outerHeight());
$(window).resize(function(){
	$('.page-content').css('min-height',$(window).height()-$('.header').outerHeight());
});


function getBlog(gb) {
	var location = gb;
	var pageURL = location.split('/');
	var blogName = pageURL[4];
	sessionStorage.selectedBlog = blogName;
}
$(document).ready(function () {
	var blogName = sessionStorage.selectedBlog;
	$("#comments_blogs_chosen > .chosen-single.chosen-default > span").html(blogName);
});

function getStatus(gs) {
	var location = gs;
	var pageURL = location.split('/');
	var statusName = pageURL[5];
	sessionStorage.selectedStatus = statusName;
}
$(document).ready(function(){
	var statusName = sessionStorage.selectedStatus;
	$(".chosen-container-single-nosearch > a.chosen-single > span").html(statusName);
	$(".sidey .nav").click(function(){
		sessionStorage.clear();
	});
});

//----------------------------
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
	$('#changeImgBlog').on('hidden.bs.modal', function () {

	})

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

	//submitting upload picture form
	$("#changeImgBlog .save-img").click(function() {
		if (!stringEndsWithValidExtension($("[id*='file-upload-blog']").val(), [".png", ".jpeg", ".jpg", ".bmp", ".gif"], false)) {
			$('.error_file').fadeIn().delay(3000).fadeOut(2000);
			return false;
		}
		//croppie avatars
		var cropData= $('#croppie_pic').croppie('get');
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

		$("#upload_blog_img").submit();
	});
});