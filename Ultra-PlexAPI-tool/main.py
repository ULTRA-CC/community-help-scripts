from plexapi.server import PlexServer

# Replace 'http://YOUR-PLEX-IP:32400' and 'YOUR-PLEX-TOKEN' with your Plex server details
plex_url = 'http://YOUR-PLEX-IP:32400'
plex_token = 'YOUR-PLEX-TOKEN'

# Connect to the Plex server
plex = PlexServer(plex_url, plex_token)

# Output file name
output_file = 'plex_media_titles_with_year.txt'

# Replace library names to align with your Plex server's library names.
with open(output_file, 'w', encoding='utf-8') as file:
    file.write("4K Movies:\n")
    for movie in plex.library.section('4K Movies').all():
        file.write(f"{movie.title} ({movie.year})\n")

    file.write("\n1080p Movies:\n")
    for movie in plex.library.section('1080p Movies').all():
        file.write(f"{movie.title} ({movie.year})\n")

    file.write("\nTV Shows:\n")
    for show in plex.library.section('TV Shows').all():
        file.write(f"{show.title} ({show.year})\n")

print(f"Media titles with release year have been written to {output_file}")
