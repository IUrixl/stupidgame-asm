# Changelog 14.09.2026 [2.00]
Fixed stupid bug i made and forgot to release patch.\
Fixed bug with cluster loading on assets.asm, it wasnt getting the offset right as the last cluster wouldnt sum the offset before loading next one.\
Fixed bug with overflow while rendering 64k bytes from the background, making the pointer go back to the start of the segment and rendering the 7 bytes header from the background sprite instead of the last 7 bytes of the background UTA file (migrated from rep movsw to a custom loop to handle overflow).\
Centered player in the middle of X.