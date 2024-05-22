#!/usr/bin/env zsh
ZSH="/usr/bin/env zsh"
BATES_FLAGS="-topleft '10 50' -bates-pad-to 6 -color 0.011 -linewidth 0.2"

# Create directory with Bates metadata in it
mkdir -p .bates

# Find all pdfs and add them to .bates/pdf_list.txt
find . -name "*.pdf" | sort -n > .bates/pdf_list.txt

# Find empty and non-empty pdfs 
rm .bates/empty_list.txt .bates/nonempty_list.txt
touch .bates/empty_list.txt .bates/nonempty_list.txt

cat .bates/pdf_list.txt | while read line
do
	size=$(stat --printf="%s" $line)
	if [ "$size" = "0" ]; then
		echo "$line" >> .bates/empty_list.txt
	else
		echo "$line" >> .bates/nonempty_list.txt
	fi
done

# For each non-empty pdf, calculate the number of pages and add the Bates command entry to number.sh
# as well as an index entry to index.txt
# In addition, add a deletion entry to clear.sh and clear_used.sh
echo "PATH\nNAME\nPAGES\nSTART_BATES\nEND_BATES\nNEW_PATH" > .bates/index.txt
echo "#!$ZSH" > .bates/number.sh
echo "#!$ZSH" > .bates/clear.sh
echo "rm .bates/log.txt" >> .bates/clear.sh
echo "#!$ZSH" > .bates/clear_used.sh

current_bates=$1
echo "Starting at $current_bates..."
cat .bates/pdf_list.txt | while read line
do
	size=$(stat --printf="%s" $line)
	pages=1
	if [ "$size" = "0" ]; then
		true
	else
		pages=$(cpdf -pages $line)
	fi

	end_bates=$((current_bates + pages - 1))
	padded_current_bates=$(printf "%06d" $current_bates)
	padded_end_bates=$(printf "%06d" $end_bates)

	safe_line=${(q+)line}

	new_name="$padded_current_bates-$padded_end_bates.pdf"
	if [ "$end_bates" = "$current_bates" ]; then
		new_name="$padded_current_bates.pdf"
	fi

	dir=$(dirname $line)
	new_path="$dir/$new_name"
	safe_new_path=${(q+)new_path}

	task_1="echo Started stamping $safe_line as $current_bates-$end_bates"

	task_2=""
	if [ "$size" = "0" ]; then
		task_2="cp $safe_line $safe_new_path"
	else
		task_2="cpdf -add-text \"%Bates\" $BATES_FLAGS -bates $current_bates $safe_line -o $safe_new_path"
	fi

	task_3="echo Done stamping $safe_line as $current_bates-$end_bates"
	task_4="echo $safe_line >> .bates/log.txt"

	echo "$task_1 && $task_2 && $task_3 && $task_4" >> .bates/number.sh

	echo "rm $safe_line" >> .bates/clear_used.sh 
	echo "rm $safe_new_path" >> .bates/clear.sh 

	index=.bates/index.txt
	echo "" >> $index
	echo "$line" >> $index
	echo "$(basename "$line")" >> $index
	echo "$pages" >> $index
	echo "$current_bates" >> $index
	echo "$end_bates" >> $index
	echo "$new_path" >> $index

	# increment bates (next bates number should actually be one higher than last)
	current_bates=$((end_bates + 1))	
done
