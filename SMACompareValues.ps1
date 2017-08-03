#	Syntax:
#	SMACompareValues.ps1 -firstValue 100 -secondValue 200
#
#	 

param (
    [string]$firstValue,
    [string]$secondValue
)

try
{
    if( $firstValue -ne $secondValue) {
        echo "values are not equal"
        exit 7501
    }

    exit 0   
}
catch
{
   echo "Error attempting to compare values" 
   exit 7500
}