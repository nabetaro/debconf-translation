<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN" CDATA dsssl>
]>
<style-sheet>

<style-specification id="html" use="docbook">
<style-specification-body> 

(define %generate-article-toc% #t)
(define %generate-article-titlepage% #t)
(define %generate-legalnotice-link% #t)
(define (article-titlepage-recto-elements)
	(list (normalize "title")
	(normalize "subtitle")
	(normalize "authorgroup")
	(normalize "author")
	(normalize "releaseinfo")
	(normalize "copyright")
	(normalize "pubdate")
	(normalize "revhistory")
	(normalize "legalnotice")
	(normalize "abstract")))

</style-specification-body>
</style-specification>

<external-specification id="docbook" document="docbook.dsl">

</style-sheet>
