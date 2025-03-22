layout=$(xkblayout-state print "%s")

if [[ "$layout" == "us" ]]; then
	echo "GUIRI";
else
	echo "ESPAÑITA";
fi;

