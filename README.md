APAT: Automated Protein Annotation Tool
=======================================

There is a frequent need to apply the same set of prediction and
annotation tools to a large batch of sequences. Such tools may reside
locally or on remote servers accessed over the web. In order to create
a meta-tool able to dispatch one or more sequences to assorted
annotation/prediction services it is necessary to define a consistent
format for the data required by such services and for the annotations
which they provide.

We have determined that the output can be described using one of 6
forms of data: numeric or textual annotation of residues, domains
(residue ranges) or whole sequences. A tool may produce a combination
of such outputs. With this in mind, an XML data-type definition (DTD)
was designed to store the output of any server (`Automated Protein
Annotation Tool Markup Language', APATML).

APAT lets you write simple wrappers for annotation servers which then
generate APATML as output. Our display program will then format that
as HTML (including colouring of residues and graphs) for you to view,
or you may write your own programs to extract and analyze the data.

A paper is available describing the system has been published in
Bioinformatics, 22,291-296.

**APAT was written by PhD student S.V.V. Deevi funded by The Felix Trust
at Reading University.**

---------------------------------------------------------------

APAT is freely available for use by not-for-profit
organisations. Commercial use is not permitted without express
permission from the author. It may not be distributed without the
author's permission, but must be obtained from this site.