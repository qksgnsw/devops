package handler

import (
    "encoding/json"
    "net/http"
    "strconv"

    "github.com/your-username/my-was-project/internal/model"
    "github.com/your-username/my-was-project/internal/repository"
)

type UserHandler struct {
    repo *repository.UserRepository
}

func NewUserHandler(repo *repository.UserRepository) *UserHandler {
    return &UserHandler{repo: repo}
}

func (h *UserHandler) RegisterUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
	var newUser model.User
    if err := json.NewDecoder(r.Body).Decode(&newUser); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    id, err := h.repo.CreateUser(newUser)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusCreated)
    w.Write([]byte(id))
}

func (h *UserHandler) LoginUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
    var loginUser model.User
    if err := json.NewDecoder(r.Body).Decode(&loginUser); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    user, err := h.repo.GetUserByUsername(loginUser.Username)
    if err != nil {
        http.Error(w, "Invalid username or password", http.StatusUnauthorized)
        return
    }

    // 실제로는 패스워드 해싱 등의 로직을 수행해야 합니다.
    if user.Password != loginUser.Password {
        http.Error(w, "Invalid username or password", http.StatusUnauthorized)
        return
    }

    // 로그인 성공
    // 세션, 토큰 등을 생성하여 클라이언트에게 전달하는 로직을 추가할 수 있습니다.
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Login successful"))
}

func (h *UserHandler) LogoutUser(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Logout successful"))
}


func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
    userID, err := strconv.Atoi(r.URL.Query().Get("id"))
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    if err := h.repo.DeleteUser(userID); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusOK)
    w.Write([]byte("User deleted successfully"))
}