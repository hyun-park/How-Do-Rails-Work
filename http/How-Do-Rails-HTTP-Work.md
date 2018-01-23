# How Do Rails HTTP Work

## Rails HTTP Structure

![rails_http_structure](https://github.com/Rocket-Hyun/How-Do-Rails-Work/blob/master/imgs/rails_http_structure2.png?raw=true)

### 클라이언트

- 웹사이트를 이용하는 사용자, 주로 브라우저를 지칭함. 이 곳에서 요청이 발생한다.
- 종류
  - Chrome, IE, Edge, Firefox, Safari 등

### 웹서버

- 클라이언트(사용자, 주로 브라우저)가 우리의 웹사이트에 보내는 요청을 받아서 처리함. 주로 Static File들을 처리하고 그 외에도 SSL, 로드밸런싱 등의 작업을 함. 자신이 처리할 수 없는 요청이면 어플리케이션(Rails)으로 넘겨줌. (는 앱서버가 받음)
- 종류  
  - Nginx, Apache 등

### 앱서버

- 어플리케이션(Rails)을 실제로 동작시키는 프로그램. 어플리케이션의 코드들을 실제로 작동시켜서 메모리에 유지한다. 웹서버로부터 요청이 오면 어플리케이션으로 전달해준다. (는 미들웨어를 이용해서 보냄) 웹서버가 없어도 스스로 동작할 수 있지만, 실제 production에서는 웹서버를 앞 단에 사용하는 것을 추천한다.
- 종류
  - (for Spring) Tomcat
  - (for Rails) Puma, Unicorn 등

### 미들웨어

- 대부분의 Rails 앱서버가 Rails 어플케이션을 실행시킬 수 있도록 도와주는 미들웨어. 단순하게 루비 웹 프레임워크(Rails, Sinatra)와 앱서버의 공용어라고 생각하면 된다. 앱서버는 Rack을 이용해 Rails 어플리케이션으로 요청을 전송한다.

### 어플리케이션

- 루비 온 레일즈 어플리케이션 자체

### 동작 시나리오

 클라이언트에서 요청을 보내면 **웹 서버**가 먼저 요청을 받아서 처리한다. 웹 서버가 스스로 처리할 수 있는 일이라면 요청에 직접 응답하고, 그게 아니라면 요청에 일부 처리를 가해서 **앱서버**로 요청을 넘긴다. 앱서버는 이를 받아서 **Rack 미들웨어**를 이용해 **Rails 어플리케이션**에 요청을 전달한다. Rails가 요청을 모두 처리해서 응답을 생성하면 다시 Rack 미들웨어를 통해 앱서버로 응답을 전송하고 앱서버는 다시 웹서버로 응답을 전송해서 최종적으로 웹서버가 클라이언트에게 응답을 전송한다.

 구체적으로 말하면, **Nginx**가 Puma에게 요청을 넘기면 **Puma**는 Rack에게 요청을 넘기고, **Rack**는 **Rails 어플리케이션**으로 요청을 넘긴다. Rails가 요청을 처리해 응답을 생성하면 정반대 경로로 클라이언트에 응답이 도달한다.


----
- 참고문서
  - [A Web Server VS An App Server](https://www.justinweiss.com/articles/a-web-server-vs-an-app-server/)
