import requests

def send_request(url, auth_token):
    try:
        # Create headers with authorization token
        headers = {
            'Authorization': f'Bearer {auth_token}'
        }

        # Send a GET request with the headers
        response = requests.get(url, headers=headers)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            # Display the data received from the request
            print("Data from GET request:")
            print(response.text)
        else:
            print(f"Failed to retrieve data. Status code: {response.status_code}")

    except requests.exceptions.RequestException as e:
        # Handle any request exceptions
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    url = "https://username.hostname.usbx.me/ultra-api/endpoint"  # Replace with your desired URL
    auth_token = "YOUR_AUTH_TOKEN"  # Replace with your actual auth token
    send_request(url, auth_token)
