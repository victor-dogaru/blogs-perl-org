

-- default admin login user : admin
-- default admin login pass : password


INSERT INTO ability VALUES
	('create blog_owner'), ('view blog_owner'  ),
	('update blog_owner'), ('delete blog_owner'),

	--
	--  Blogs encompass blog_tag, blog_category, blog_blog
	--
	('create blog'), ('view blog'  ),
	('update blog'), ('delete blog'),

	--
	-- Categories
	--
	('create category'), ('view category'  ),
	('update category'), ('delete category'),

	('create comment'), ('view comment'  ),
	('update comment'), ('delete comment'),

	--
	--  Pages encompass page_tag, page_category, blog_page
	--
	('create page'), ('view page'  ),
	('update page'), ('delete page'),

	--
	--  Posts encompass post_tag, post_category, blog_post
	--
	('create post'), ('view post'  ),
	('update post'), ('delete post'),

	('create profile'), ('view profile'  ),
	('update profile'), ('delete profile'),

	('create tag'), ('view tag'  ),
	('update tag'), ('delete tag'),

	('create user'), ('view user'  ),
	('update user'), ('delete user')
;


INSERT INTO role VALUES
	('super_admin'),
	('admin'),
	('author'),
	('visitor')
;


INSERT INTO acl VALUES
       ('super_admin','create blog_owner'),
       ('super_admin','view blog_owner'  ),
       ('super_admin','update blog_owner'),
       ('super_admin','delete blog_owner'),

       ('super_admin','create blog'),
       ('super_admin','view blog'  ),
       ('super_admin','update blog'),
       ('super_admin','delete blog'),

       ('super_admin','create category'),
       ('super_admin','view category'  ),
       ('super_admin','update category'),
       ('super_admin','delete category'),

       ('super_admin','create comment'),
       ('super_admin','view comment'  ),
       ('super_admin','update comment'),
       ('super_admin','delete comment'),

       ('super_admin','create page'),
       ('super_admin','view page'  ),
       ('super_admin','update page'),
       ('super_admin','delete page'),

       ('super_admin','create post'),
       ('super_admin','view post'  ),
       ('super_admin','update post'),
       ('super_admin','delete post'),

       ('super_admin','create profile'),
       ('super_admin','view profile'  ),
       ('super_admin','update profile'),
       ('super_admin','delete profile'),

       ('super_admin','create tag'),
       ('super_admin','view tag'  ),
       ('super_admin','update tag'),
       ('super_admin','delete tag'),

       ('super_admin','create user'),
       ('super_admin','view user'  ),
       ('super_admin','update user'),
       ('super_admin','delete user'),


       -- ('super_admin','create blog_owner'),
       -- ('super_admin','view blog_owner'  ),
       -- ('super_admin','update blog_owner'),
       -- ('super_admin','delete blog_owner'),

       ('admin','create blog'),
       ('admin','view blog'  ),
       ('admin','update blog'),
       ('admin','delete blog'),

       ('admin','create category'),
       ('admin','view category'  ),
       ('admin','update category'),
       ('admin','delete category'),

       ('admin','create comment'),
       ('admin','view comment'  ),
       ('admin','update comment'),
       ('admin','delete comment'),

       ('admin','create page'),
       ('admin','view page'  ),
       ('admin','update page'),
       ('admin','delete page'),

       ('admin','create post'),
       ('admin','view post'  ),
       ('admin','update post'),
       ('admin','delete post'),

       ('admin','create profile'),
       ('admin','view profile'  ),
       ('admin','update profile'),
       ('admin','delete profile'),

       ('admin','create tag'),
       ('admin','view tag'  ),
       ('admin','update tag'),
       ('admin','delete tag'),

       ('admin','create user'),
       ('admin','view user'  ),
       ('admin','update user'),
       ('admin','delete user'),


       -- ('author','create blog_owner'),
       -- ('author','view blog_owner'  ),
       -- ('author','update blog_owner'),
       -- ('author','delete blog_owner'),

       ('author','create blog'),
       ('author','view blog'  ),
       ('author','update blog'),
       ('author','delete blog'),

       ('author','create category'),
       ('author','view category'  ),
       ('author','update category'),
       ('author','delete category'),

       ('author','create comment'),
       ('author','view comment'  ),
       ('author','update comment'),
       ('author','delete comment'),

       ('author','create page'),
       ('author','view page'  ),
       ('author','update page'),
       ('author','delete page'),

       ('author','create post'),
       ('author','view post'  ),
       ('author','update post'),
       ('author','delete post'),

       ('author','create profile'),
       ('author','view profile'  ),
       ('author','update profile'),
       ('author','delete profile'),

       ('author','create tag'),
       ('author','view tag'  ),
       ('author','update tag'),
       ('author','delete tag'),

       -- ('author','create user'),
       -- ('author','view user'  ),
       -- ('author','update user'),
       -- ('author','delete user'),


       -- ('visitor','create blog_owner'),
       -- ('visitor','view blog_owner'  ),
       -- ('visitor','update blog_owner'),
       -- ('visitor','delete blog_owner'),

       -- ('visitor','create blog'),
       ('visitor','view blog'  ),
       -- ('visitor','update blog'),
       -- ('visitor','delete blog'),

       -- ('visitor','create category'),
       ('visitor','view category'  ),
       -- ('visitor','update category'),
       -- ('visitor','delete category'),

       -- ('visitor','create comment'),
       ('visitor','view comment'  ),
       -- ('visitor','update comment'),
       -- ('visitor','delete comment'),

       -- ('visitor','create page'),
       ('visitor','view page'  ),
       -- ('visitor','update page'),
       -- ('visitor','delete page'),

       -- ('visitor','create post'),
       ('visitor','view post'  ),
       -- ('visitor','update post'),
       -- ('visitor','delete post'),

       -- ('visitor','create profile'),
       ('visitor','view profile'  ),
       -- ('visitor','update profile'),
       -- ('visitor','delete profile'),

       -- ('visitor','create tag'),
       ('visitor','view tag'  ),
       -- ('visitor','update tag'),
       -- ('visitor','delete tag'),

       -- ('visitor','create user'),
       ('visitor','view user'  )
       -- ('visitor','update user'),
       -- ('visitor','delete user')
;


INSERT INTO post_format VALUES('HTML'),
                              ('Markdown'),
                              ('Markdown_With_Smartypants'),
                              ('RichText'),
                              ('Textile2');


INSERT INTO theme VALUES('light'),
                        ('dark');


INSERT INTO oauth VALUES('OpenAuth'),
                        ('LinkedIn'),
                        ('Facebook'),
                        ('StackOverflow'),
                        ('GitHub'),
                        ('Twitter');

--
-- Administrator users are created during the import
--

-- INSERT INTO users VALUES (1,'Admin','admin','ddd8f33fbc8fd3ff70ea1d3768e7c5c151292d3a8c0972','2015-02-18 15:27:54','admin@admin.com',NULL,NULL,'admin',NULL,'active');
	
-- INSERT INTO category VALUES (1,'Uncategorized','uncategorized',1);


INSERT INTO settings VALUES ('Europe/Bucharest',1,'','/','BlogsPerlOrg',1,0);
