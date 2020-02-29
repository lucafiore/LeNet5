cnt=0;
files_tot='';
for folder in $(ls | grep 'VHDL'); do
	path='../src/'$folder'/';
	cd $folder;
	rm -f *.bak
	for file in $(ls); do
		path_file=${path}$file;
		if [[ $cnt -eq 0 ]] ; then
			files_tot=${path_file}' ';
			cnt=1;
		else 
			files_tot=${files_tot}$path_file' ';
		fi	
	done	
	cd ..
done

echo $files_tot
