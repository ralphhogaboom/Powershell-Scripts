# Uses yt-dlp to download spotify playlists, and sort by artist/album/title for quicker injestion.
# To set this up, create a scheduled task to execute this script every 5 minutes. 
# Then paste a spotify album URI into e:\requests.txt. The script will do the rest.
# Requires: FFMPEG. Run it interactively the first few times to make sure you got it right.

cd e:\music
foreach ($line in  get-content e:\requests.txt) {
	$runline = 'spotdl ' + $line + ' -p "{artists}/{album}/{title}.{ext}"'
    invoke-expression $runline
	#start-process $runline
	#call $runline
}
remove-item e:\requests.txt
new-item e:\requests.txt
