# https://github.com/baxpr/fsl-base
# This base container has FSL and ImageMagick installed
FROM baxterprogers/fsl-base:v6.0.5.2

# Pipeline code
COPY roi_extract.sh /opt/hippo-alff/roi_extract.sh
COPY xwrapper.sh /opt/hippo-alff/xwrapper.sh
ENV PATH=/opt/hippo-alff:${PATH}

# Entrypoint
ENTRYPOINT ["xwrapper.sh","roi_extract.sh"]
