cat opens_sans-roboto-poppins.css | grep url | while read line
do
    URL=$(echo $line | awk -F'(' {'print $2'} | awk -F')' {'print $1'}) 
    FONT=$(echo $line | awk -F'(' {'print $2'} | awk -F')' {'print $1'} | awk -F'/' {'print $5'}) 
    VERSION=$(echo $line | awk -F'(' {'print $2'} | awk -F')' {'print $1'} | awk -F'/' {'print $6'}) 
    FILENAME=$(echo $line | awk -F'(' {'print $2'} | awk -F')' {'print $1'} | awk -F'/' {'print $7'}) 
    echo $URL
    echo $FONT
    echo $VERSION
    echo $FILENAME
    mkdir -p ${FONT}/${VERSION}
    wget $URL -O ${FONT}/${VERSION}/${FILENAME}
done
