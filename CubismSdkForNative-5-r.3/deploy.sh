export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
ROOT_DIR=$(cd $(dirname $0) && pwd)
echo "ROOT_DIR: $ROOT_DIR"
RENDER_METHOD=NONE
TARGETOS=NONE
PS3="Select the Target No. to use: "
select var in 'OpenGL' 'Metal'
do
  case "$var" in
    'OpenGL' ) TARGETOS=ios; RENDER_METHOD=OpenGL ;;
    'Metal' ) TARGETOS=ios; RENDER_METHOD=Metal ;;
    * ) echo "Invalid option $REPLY." ;;
  esac
  break
done

if [ "$RENDER_METHOD" = NONE ]; then
  exit -1
fi

SAMPLE_DIR="$ROOT_DIR/Samples" 
echo "SAMPLE_DIR: $SAMPLE_DIR"
RENDER_METHOD_DIR="$SAMPLE_DIR/$RENDER_METHOD"
echo "RENDER_METHOD_DIR: $RENDER_METHOD_DIR"
DEMO_DIR="$RENDER_METHOD_DIR/Demo"
echo "DEMO_DIR: $DEMO_DIR"

THIRD_PARTY_DIR="$RENDER_METHOD_DIR/thirdParty"
echo "THIRD_PARTY_DIR: $THIRD_PARTY_DIR"
INSTALL_SCRIPTS_PATH="$THIRD_PARTY_DIR/scripts/setup_ios_cmake"

sh $INSTALL_SCRIPTS_PATH

CMAKE_SCRIPTS_DIR="$DEMO_DIR/proj.ios.cmake/scripts"
CMAKE_SCRIPT_PATH="$CMAKE_SCRIPTS_DIR/proj_xcode"
sh $CMAKE_SCRIPT_PATH