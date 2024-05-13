# Uses yt-dlp to download spotify playlists, and sort by artist/album/title for quicker injestion.
# To set this up, create a scheduled task to execute this script every 5 minutes. 
# Then paste a spotify album URI into e:\playlists.txt. The script will do the rest.
# Requires: FFMPEG. Run it interactively the first few times to make sure you got it right.

foreach ($line in  get-content e:\playlists.txt) {
	$runline = "spotdl " + $line + ' --m3u --output E:\music -p "{artists}/{album}/{title}.{ext}"'
    invoke-expression $runline 
}
remove-item e:\playlists.txt
new-item e:\playlists.txt
