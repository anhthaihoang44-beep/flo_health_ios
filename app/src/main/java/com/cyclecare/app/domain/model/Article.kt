package com.cyclecare.app.domain.model

data class Article(
    val id: String,
    val title: String,
    val body: String,
    val category: String,
    val locale: String = "vi",
    val isPremium: Boolean = false
)
