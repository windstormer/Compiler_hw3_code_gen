	! BEGIN EPILOGUE
	addi    $sp, $fp, 0
	lwi     $fp, [$sp+4]
	addi	$sp, $sp, 8
	pop.s	{ $lp }
	ret
	! END EPILOGUE
	.size	_Z4loopv, .-_Z4loopv
	.ident	"GCC: (2015-08-24_nds32le-elf-mculib-v3m) 4.9.2"
	! ------------------------------------