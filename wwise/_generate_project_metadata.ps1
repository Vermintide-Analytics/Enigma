# Specify the path to your CSV file
$csvFilePath = ".\_METADATA_GENERATION_INPUT.csv"
$outputFilePath = ".\project.wwise_metadata"

# Initialize an array to store the data
$dataArray = @()

# Read the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Loop through each row in the CSV data
foreach ($row in $csvData) {
    # Create an object with properties for name, duration_min, duration_max, and duration_type
    $entry = [PSCustomObject]@{
        Name          = $row.Name
        Duration_Min  = $row.Duration_Min
        Duration_Max  = $row.Duration_Max
        Duration_Type = $row.Duration_Type
		Loop_Count    = $row.Loop_Count
    }
	
	if ([string]::IsNullOrEmpty($entry.Duration_Max)) {
		$entry.Duration_Max = $entry.Duration_Min
	}
	if ([string]::IsNullOrEmpty($entry.Duration_Type)) {
		$entry.Duration_Type = "OneShot"
	}
	if ($entry.Duration_Type -eq "Loop" -and [string]::IsNullOrEmpty($entry.Loop_Count)) {
		$entry.Loop_Count = 0
	}

    # Add the entry to the array
    $dataArray += $entry
}

# Display the data in the array (optional)
$dataArray | Format-Table



$output = @"

aux_buses = [
]
banks = {
	Enigma = {
		events = [

"@

foreach ($entry in $dataArray) {
    $output += "`t`t`t`"" + $entry.Name + "`"`r`n"
}

$output += @"
		]
	}
}
buses = [
	"Master Audio Bus"
]
events = {

"@

foreach ($entry in $dataArray) {
    $output += "`t" + $entry.Name + " = {`r`n"
	$output += "`t`tattenuation_max = 0`r`n"
	$output += "`t`tduration_max = " + $entry.Duration_Max + "`r`n"
	$output += "`t`tduration_min = " + $entry.Duration_Min + "`r`n"
	$output += "`t`tduration_type = `"" + $entry.Duration_Type + "`"`r`n"
	if ($entry.Duration_Type -eq "Loop") {
	$output += "`t`tloop_count = " + $entry.Loop_Count + "`r`n"
	}
	$output += "`t`tpositioning = `"2D`"`r`n`t}`r`n"
}

$output += @"
}
parameters = [
]
state_groups = {
}
switch_groups = {
}
triggers = [
]
"@

Write-Output $output
$output | Out-File -FilePath $outputFilePath -Encoding UTF8











