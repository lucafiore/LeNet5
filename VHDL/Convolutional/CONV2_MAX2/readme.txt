SIMULAZIONE

STEP DA SEGUIRE per simulare il convolutional layer 2:
- eseguire lo script MATLAB "Convolutional_2.m" (nella cartella MATLAB);
- aprire Modelsim, cambiare directory e posizionarsi dentro la cartella "VHDL", lanciare lo script "compile.do" dalla linea di comando di Modelsim;
- eseguire lo script "Compare_results" (nella cartella MATLAB).



INFORMAZIONI FILE

Lo script matlab "./MATLAB_script/Convolutional_2.m" genera i
file di pesi e bias in binario con parallelismo 8 bit, ricavati dall'allenamento (20 epoche) della rete implementata in Python, e i golden file di input e output in binario con parallelismo 8 bit ricavati per l'immagine n°0 presa dal dataset "MNIST-test".
I file di input, pesi e bias andranno al testbench del layer.


Lo script "./VHDL/compile.do" crea la cartella "work", compila tutti i file vhdl utili e lancia la simulazione della top entity ("network2") per 280 us.
Dalla simulazione viene generato un file di output ("fileOutputsVHDL_conv2") salvato nella cartella "./MATLAB_script".


Lo script matlab "./MATLAB_script/Compare_results.m" compara i risultati ricavati col modello MATLAB con quelli ricavati con l'implementazione hardware in vhdl e mostra tramite grafico la differenza elemento per elemento delle uscite.