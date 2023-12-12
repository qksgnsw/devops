package handler

import (
    "encoding/json"
    "net/http"
    "strconv"

    "github.com/workingscv/backend/internal/model"
    "github.com/workingscv/backend/internal/repository"
)

type MemoHandler struct {
    repo *repository.MemoRepository
}

func NewMemoHandler(repo *repository.MemoRepository) *MemoHandler {
    return &MemoHandler{repo: repo}
}

func (h *MemoHandler) Memo(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
    case http.MethodPost:
    h.createMemo(w, r)
    case http.MethodGet:
    h.getMemo(w, r)
    case http.MethodPut:
    h.updateMemo(w, r)
    case http.MethodDelete:
    h.deleteMemo(w, r)
	}
}

func (h *MemoHandler) createMemo(w http.ResponseWriter, r *http.Request) {
    var newMemo model.Memo
    if err := json.NewDecoder(r.Body).Decode(&newMemo); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    id, err := h.repo.CreateMemo(newMemo)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusCreated)
    w.Write([]byte(strconv.Itoa(id)))
}

func (h *MemoHandler) getMemo(w http.ResponseWriter, r *http.Request) {
    id, err := strconv.Atoi(r.URL.Query().Get("id"))
    if err != nil {
        http.Error(w, "Invalid memo ID", http.StatusBadRequest)
        return
    }

    memo, err := h.repo.GetMemoByID(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    jsonResponse, err := json.Marshal(memo)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    w.Write(jsonResponse)
}

func (h *MemoHandler) updateMemo(w http.ResponseWriter, r *http.Request) {
    var updatedMemo model.Memo
    if err := json.NewDecoder(r.Body).Decode(&updatedMemo); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    if err := h.repo.UpdateMemo(updatedMemo); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.WriteHeader(http.StatusOK)
}

func (h *MemoHandler) deleteMemo(w http.ResponseWriter, r *http.Request) {
    id, err := strconv.Atoi(r.URL.Query().Get("id"))
    if err != nil {
        http.Error(w, "Invalid memo ID", http.StatusBadRequest)
        return
    }

    if err := h.repo.DeleteMemo(id); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.WriteHeader(http.StatusOK)
}

func (h *MemoHandler) GetAllMemos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    memos := h.repo.GetAllMemos()

    jsonResponse, err := json.Marshal(memos)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    w.Write(jsonResponse)
}
