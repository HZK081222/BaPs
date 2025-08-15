git clone https://github.com/asfu222/BlueArchiveLocalizationTools
pip3 install -r BlueArchiveLocalizationTools/requirements.txt
python3 BlueArchiveLocalizationTools/update_urls.py ba.env ./data/ServerInfo.json
export $(grep -v '^#' ba.env | xargs)
echo Using catalog url: $ADDRESSABLE_CATALOG_URL
mkdir -p resources/TableBundles
curl "${ADDRESSABLE_CATALOG_URL}/TableBundles/Excel.zip" -o resources/TableBundles/Excel.zip
curl "${ADDRESSABLE_CATALOG_URL}/TableBundles/ExcelDB.db" -o resources/TableBundles/ExcelDB.db

python3 fetch_resources.py
