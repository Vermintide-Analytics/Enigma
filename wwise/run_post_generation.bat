del .\Init.wwise_bank
del .\Init.wwise_dep
del .\Enigma.wwise_dep
powershell .\_generate_project_metadata.ps1
p4merge .\mods\Enigma\project.wwise_metadata .\project.wwise_metadata 