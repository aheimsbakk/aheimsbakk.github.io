---
title: Only Firefox is safe post Heartblead
date: 2014-05-12
draft: false
categories:
  - uris
tags:
  - link
  - security
---
o[Steve Gibson] have a nice round-up where he explains how certificate revocation does work and why Chrome and Chromiums certificate revocation scheme doesn't work. I recommend to read both [Steve Gibson]'s article on [An Evaluation of the Effectiveness of Chrome's CRLSets](https://www.grc.com/revocation/crlsets.htm) and Adam Langley's in my opinion a bit missplaced answer [Revocation still doesn't work](https://www.imperialviolet.org/2014/04/29/revocationagain.html).

* [Security Certificate - Revocation Awareness Test](https://www.grc.com/revocation.htm)

* Listen to [Security Now!](https://www.grc.com/securitynow.htm) episode 454 [Certificate Revocation Part 2](https://www.grc.com/securitynow.htm#454) in which Steve explains about both certificate revocation and Google's CRLSets.

## How to be safe

1. Use Firefox until Chrome is fixed.

2. In Firefox enable hard fail on [OCSP] errors. 

    Goto **Preferences** → **Advanced** → **Certificates** → **Validation**.
    
    Check **When an OSCP server connection failes, treat the certificate as invalid.**


[OCSP]: https://en.wikipedia.org/wiki/OCSP "Online Certificate Status Protocol"
[Steve Gibson]: https://en.wikipedia.org/wiki/Steve_Gibson_%28computer_programmer%29
[Adam Langley]: 

