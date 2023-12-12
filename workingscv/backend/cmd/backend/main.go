package main

import (
    "log"
    "net/http"

    "github.com/workingscv/backend/internal/handler"
    "github.com/workingscv/backend/internal/repository"
)

func main() {
    repo := repository.NewMemoRepository()
    memoHandler := handler.NewMemoHandler(repo)

    http.HandleFunc("/memo", memoHandler.Memo)
    http.HandleFunc("/memo/all", memoHandler.GetAllMemos)

	repo := repository.NewUserRepository()
	userHandler := handler.NewUserHandler(repo)

	http.HandleFunc("/user/register", userHandler.RegisterUser)
	http.HandleFunc("/user/login", userHandler.LoginUser)
	http.HandleFunc("/user/logout", userHandler.LogoutUser)
	http.HandleFunc("/user/delete", userHandler.DeleteUser)

    log.Fatal(http.ListenAndServe(":8080", nil))
}
