REGION="europe-west1"
APP=$(node -e "console.log(require('./package.json').name)")
PROJECT=$APP
PROJECT_ID=$(gcloud projects list --filter="PROJECT_NAME=$PROJECT" --format="value(PROJECT_ID)")

if [[ -z "$PROJECT_ID" ]]; 
then
  printError "Invalid project id $PROJECT_ID";
fi

IMAGE_PATH=$REGION-docker.pkg.dev/$PROJECT_ID/images
GIT_REV_SHORT=$(git rev-parse --short=8 HEAD)
IMAGE=$IMAGE_PATH/$PROJECT:$GIT_REV_SHORT

echo "PROJECT = "$PROJECT
echo "APP = "$APP
echo "GIT_REV_SHORT = "$GIT_REV_SHORT
echo "PROJECT_ID = "$PROJECT_ID
echo "IMAGE = "$IMAGE
echo "REGION = "$REGION


#gcloud builds submit --project=$PROJECT_ID --tag=$IMAGE --region=$REGION

#gcloud run deploy $APP --project=$PROJECT_ID --image=$IMAGE --region=$REGION
